<?php

declare(strict_types=1);

namespace TextileDrop\Core;

class Validator
{
    private array $data;
    private array $rules;
    private array $errors = [];

    public function __construct(array $data, array $rules)
    {
        $this->data = $data;
        $this->rules = $rules;
    }

    public static function make(array $data, array $rules): self
    {
        return new self($data, $rules);
    }

    public function validate(): bool
    {
        $this->errors = [];

        foreach ($this->rules as $field => $ruleString) {
            $fieldRules = is_array($ruleString) ? $ruleString : explode('|', $ruleString);
            $value = $this->data[$field] ?? null;

            foreach ($fieldRules as $rule) {
                $params = [];
                if (str_contains($rule, ':')) {
                    [$ruleName, $paramStr] = explode(':', $rule, 2);
                    $params = explode(',', $paramStr);
                } else {
                    $ruleName = $rule;
                }

                $ruleName = trim($ruleName);

                if ($ruleName === 'required' && ($value === null || $value === '')) {
                    $this->addError($field, "The {$field} field is required.");
                    break;
                }

                if ($value === null || $value === '') {
                    continue;
                }

                switch ($ruleName) {
                    case 'email':
                        if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
                            $this->addError($field, "The {$field} must be a valid email address.");
                        }
                        break;
                    case 'numeric':
                        if (!is_numeric($value)) {
                            $this->addError($field, "The {$field} must be a number.");
                        }
                        break;
                    case 'integer':
                        if (filter_var($value, FILTER_VALIDATE_INT) === false) {
                            $this->addError($field, "The {$field} must be an integer.");
                        }
                        break;
                    case 'min':
                        $min = (int)($params[0] ?? 0);
                        if (is_string($value) && mb_strlen($value) < $min) {
                            $this->addError($field, "The {$field} must be at least {$min} characters.");
                        } elseif (is_numeric($value) && (float)$value < $min) {
                            $this->addError($field, "The {$field} must be at least {$min}.");
                        }
                        break;
                    case 'max':
                        $max = (int)($params[0] ?? 0);
                        if (is_string($value) && mb_strlen($value) > $max) {
                            $this->addError($field, "The {$field} may not be greater than {$max} characters.");
                        } elseif (is_numeric($value) && (float)$value > $max) {
                            $this->addError($field, "The {$field} may not be greater than {$max}.");
                        }
                        break;
                    case 'in':
                        if (!in_array((string)$value, $params, true)) {
                            $this->addError($field, "The selected {$field} is invalid.");
                        }
                        break;
                }
            }
        }

        return empty($this->errors);
    }

    private function addError(string $field, string $message): void
    {
        $this->errors[$field][] = $message;
    }

    public function errors(): array
    {
        return $this->errors;
    }

    public function firstError(): ?string
    {
        foreach ($this->errors as $fieldErrors) {
            return $fieldErrors[0] ?? null;
        }
        return null;
    }
}

